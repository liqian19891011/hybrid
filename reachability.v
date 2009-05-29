Require Import util.
Set Implicit Arguments.

Section contents.

  Variables (State: Type) (trans: State -> State -> Prop).

  Inductive reachable: State -> State -> Prop :=
    | reachable_refl s: reachable s s
    | reachable_next a b c: reachable a b ->
        trans b c -> reachable a c.

  Inductive path: State -> State -> Type :=
    | path_refl s: path s s
    | path_next a b c: path a b -> trans b c -> path a c.

  Hint Constructors reachable.

  Lemma reachable_trans a b: reachable a b -> forall c, reachable b c ->
    reachable a c.
  Proof. induction 2; eauto. Qed.

  Inductive reachable_irrefl: State -> State -> Prop :=
    | reachable_one s s': trans s s' -> reachable_irrefl s s'
    | reachable_more a b c: reachable_irrefl a b ->
        trans b c -> reachable_irrefl a c.

  Lemma reachable_flip (P: State -> Prop) (Pdec: forall s, decision (P s))
   (a b: State): reachable a b -> P a -> ~ P b ->
    exists c, exists d, P c /\ ~ P d /\ trans c d.
  Proof.
    intros P Pdec a b r.
    induction r. firstorder.
    destruct (Pdec b); eauto.
  Qed.

  Lemma reachable_flip_inv (P: State -> Prop) (Pdec: forall s, decision (P s))
   (a b: State): reachable a b -> ~ P a -> P b ->
    exists c, exists d, ~ P c /\ P d /\ trans c d.
  Proof.
    intros P Pdec a b r.
    induction r. firstorder.
    destruct (Pdec b); eauto.
  Qed.

  Variable t: bool -> State -> State -> Prop.

  Inductive end_with: bool -> State -> State -> Prop :=
    | end_with_refl b s: end_with b s s
    | end_with_next b x y:
        end_with (negb b) x y -> forall z, t b y z -> end_with b x z.

  Definition reachable_alternating (s s': State): Prop :=
    exists b, end_with b s s'.

End contents.

Hint Constructors end_with.
Hint Unfold reachable_alternating.
